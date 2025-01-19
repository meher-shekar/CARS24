# Q4. Write a python program to flatten a nested JSON to list all the available nic into dataframe.
# Use below JSON data for reference.
"""
{
    "count": 13,
    "virtualmachine": [
        {
            "id": "1082e2ed-ff66-40b1-a41b-26061afd4a0b",
            "name": "test-2",
            "displayname": "test-2",
            "securitygroup": [
                {
                    "id": "9e649fbc-3e64-4395-9629-5e1215b34e58",
                    "name": "test",
                    "tags": []
                }
            ],
            "nic": [
                {
                    "id": "79568b14-b377-4d4f-b024-87dc22492b8e",
                    "networkid": "05c0e278-7ab4-4a6d-aa9c-3158620b6471"
                },
                {
                    "id": "3d7f2818-1f19-46e7-aa98-956526c5b1ad",
                    "networkid": "b4648cfd-0795-43fc-9e50-6ee9ddefc5bd",
                    "traffictype": "Guest"
                }
            ],
            "hypervisor": "KVM",
            "affinitygroup": [],
            "isdynamicallyscalable": False
        }
    ]
}
"""
import pandas as pd

nested_json = {
    "count": 13,
    "virtualmachine": [
        {
            "id": "1082e2ed-ff66-40b1-a41b-26061afd4a0b",
            "name": "test-2",
            "displayname": "test-2",
            "securitygroup": [
                {
                    "id": "9e649fbc-3e64-4395-9629-5e1215b34e58",
                    "name": "test",
                    "tags": [],
                }
            ],
            "nic": [
                {
                    "id": "79568b14-b377-4d4f-b024-87dc22492b8e",
                    "networkid": "05c0e278-7ab4-4a6d-aa9c-3158620b6471",
                },
                {
                    "id": "3d7f2818-1f19-46e7-aa98-956526c5b1ad",
                    "networkid": "b4648cfd-0795-43fc-9e50-6ee9ddefc5bd",
                    "traffictype": "Guest",
                },
            ],
            "hypervisor": "KVM",
            "affinitygroup": [],
            "isdynamicallyscalable": False,
        }
    ],
}
# Normalize JSON data to extract NIC information along with other details
nic_df = pd.json_normalize(
    nested_json["virtualmachine"],
    record_path="nic",
    meta=[
        "id",
        "name",
        "displayname",
        "securitygroup",
        "hypervisor",
        "affinitygroup",
        "isdynamicallyscalable",
    ],
    meta_prefix="vm_",
).rename(
    columns={
        "id": "nic_id",
        "networkid": "nic_networkid",
        "traffictype": "nic_traffictype",
        "vm_id": "id",
        "vm_name": "name",
        "vm_displayname": "displayname",
        "vm_securitygroup": "securitygroup",
        "vm_hypervisor": "hypervisor",
        "vm_affinitygroup": "affinitygroup",
        "vm_isdynamicallyscalable": "isdynamicallyscalable",
    },
    inplace=True,
)

print(nic_df)
